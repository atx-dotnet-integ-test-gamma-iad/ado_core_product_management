# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with compatibility shims or may behave differently on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Drawing` (requires additional NuGet packages on non-Windows)
- `Microsoft.Win32` registry APIs (Windows-only)
- `System.Runtime.InteropServices` P/Invoke calls targeting Windows-specific DLLs
- `AppDomain` and `Thread.Abort` (partially removed in modern .NET)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 5. Review NuGet Package Versions

Open the `.csproj` file and verify all NuGet packages are referencing versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, being cautious of breaking changes between major versions.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable access, and any OS-specific behavior.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `linux-arm64`, etc.) as needed.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published output directly to perform a final smoke test:

```bash
./AdoCore
```

or on Windows:

```bash
AdoCore.exe
```