# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues, which indicates the migration to cross-platform .NET was completed without introducing any breaking changes at the build level.

## Validation Steps

### 1. Restore and Build the Solution

Run the following commands to confirm a clean restore and build from the command line:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that the output shows zero errors and zero warnings (or review any warnings that may exist for potential issues).

### 2. Run Existing Tests

If the solution contains any test projects, execute them to confirm runtime behavior is intact:

```bash
dotnet test --configuration Release --verbosity normal
```

Review the test output for any failures or unexpected skipped tests.

### 3. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version installed on all target machines.

### 4. Check for Runtime-Specific Dependencies

Even though the project builds successfully, review the project's NuGet dependencies for any packages that may have platform-specific behavior or that target `net4x` (legacy .NET Framework). Run:

```bash
dotnet list package
```

Look for any packages that may need to be updated to versions with cross-platform support.

### 5. Validate Application Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior matches the legacy version:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File system path handling (e.g., hardcoded backslashes)
- Any use of Windows-specific APIs such as the registry, WMI, or COM interop
- Environment variable assumptions

### 6. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the output in the `publish` folder to confirm all required files are present before deploying to the target environment.