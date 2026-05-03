# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only target `net4x` with their cross-platform equivalents where necessary.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may reference APIs that are Windows-only. Use the .NET Compatibility Analyzer to surface these at build time by adding the following to `AdoCore.csproj`:

```xml
<PropertyGroup>
  <PlatformNeutralAssembly>true</PlatformNeutralAssembly>
</PropertyGroup>
```

Alternatively, run the following analyzer tool:

```bash
dotnet tool install -g dotnet-apicompat
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Registry access calls, which are Windows-only
- `System.Drawing` usage, which requires additional native dependencies on Linux and macOS
- Any use of `AppDomain` or remoting APIs that were removed in .NET Core and later

## 7. Publish the Application

Once runtime behavior is validated, publish a self-contained or framework-dependent build for your target platform:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and confirm all required assets and configuration files are present before deploying to the target environment.