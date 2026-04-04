# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility shims that may cause runtime issues.

## 3. Review NuGet Package Compatibility

Check all NuGet dependencies in `AdoCore.csproj` to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Any packages still referencing `net4x` or older targets may cause unexpected behavior at runtime even if the build succeeds.

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Run Existing Tests

If there are test projects in the solution, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results for any failures that may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even with a successful build, certain APIs behave differently or are unavailable on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any such issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay close attention to any diagnostics related to:
- `System.Windows` namespaces
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain` usage

## 6. Validate Runtime Behavior

Run the application manually or via integration tests on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Compare output and behavior against the original legacy application to identify any regressions.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment (e.g., `win-x64`, `osx-x64`).

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm all expected files are present, including configuration files (e.g., `appsettings.json`) and any required assets that were part of the original project.