# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to GAC assemblies have been replaced with the appropriate NuGet `<PackageReference>` entries.
- No Windows-specific SDK references (e.g., `Microsoft.WindowsDesktop.App`) are present unless they are intentional.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to current stable versions in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any remaining warnings, particularly:
- `CS0618` (obsolete API usage)
- `CS8600`–`CS8625` (nullable reference warnings, if nullable is enabled)
- Platform compatibility warnings (`CA1416`)

## 4. Run the Existing Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Ensure all previously passing tests continue to pass. Investigate any failures, as they may indicate API behavioral differences between .NET Framework and modern .NET.

## 5. Verify Platform-Specific Code

Search the codebase for APIs that are not fully supported on all platforms:

- `System.Drawing` (limited on Linux/macOS without additional packages)
- `Microsoft.Win32.Registry`
- `System.Windows.Forms` or `System.Web` references
- P/Invoke calls to Windows-only native libraries

Use the .NET Compatibility Analyzer or the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) to identify any remaining compatibility issues.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Confirm that file paths, line endings, environment variable access, and any OS-specific logic behave correctly on non-Windows systems.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained, platform-specific binary:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment (`win-x64`, `osx-x64`, `osx-arm64`, etc.).

For a framework-dependent deployment (requires .NET runtime installed on the target machine):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Review the output in the `publish` folder to confirm all required files are present before deploying to the target environment.